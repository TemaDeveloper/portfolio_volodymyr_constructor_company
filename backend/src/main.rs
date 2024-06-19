use axum::{
    extract::Host, handler::HandlerWithoutStateExt, http::Uri, response::Redirect, BoxError,
};
use axum_server::tls_rustls::RustlsConfig;
use backend::create_routes;
use dotenv::dotenv;
use futures::Future;
use reqwest::StatusCode;
use std::{env, net::SocketAddr, path::PathBuf, time::Duration};
use tokio::signal;

#[derive(Clone, Copy)]
struct Ports {
    http: u16,
    https: u16,
}

const fn get_ports() -> Ports {
    if cfg!(debug_assertions) {
        Ports {
            http: 3000,
            https: 8000,
        }
    } else {
        Ports {
            http: 80,
            https: 443,
        }
    }
}

/* (VISITOR_DIR, ADMIN_DIR, CERT_DIR) */
fn read_env() -> anyhow::Result<(String, String, String)> {
    Ok((
        env::var("VISITOR_DIR")?,
        env::var("ADMIN_DIR")?,
        env::var("CERT_DIR")?,
    ))
}

async fn shutdown(handle: axum_server::Handle) {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("Received termination signal shutting down");
    handle.graceful_shutdown(Some(Duration::from_secs(5)));
}

async fn redirect_http_to_https<F>(ports: Ports, signal: F)
where
    F: Future<Output = ()> + Send + 'static,
{
    fn make_https(host: String, uri: Uri, ports: Ports) -> Result<Uri, BoxError> {
        let mut parts = uri.into_parts();

        parts.scheme = Some(axum::http::uri::Scheme::HTTPS);

        if parts.path_and_query.is_none() {
            parts.path_and_query = Some("/".parse().unwrap());
        }

        let https_host = host.replace(&ports.http.to_string(), &ports.https.to_string());
        parts.authority = Some(https_host.parse()?);

        Ok(Uri::from_parts(parts)?)
    }

    let redirect = move |Host(host): Host, uri: Uri| async move {
        match make_https(host, uri, ports) {
            Ok(uri) => Ok(Redirect::permanent(&uri.to_string())),
            Err(error) => {
                tracing::warn!(%error, "failed to convert URI to HTTPS");
                Err(StatusCode::BAD_REQUEST)
            }
        }
    };

    let addr = SocketAddr::from(([127, 0, 0, 1], ports.http));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    tracing::debug!("listening on {addr}");
    axum::serve(listener, redirect.into_make_service())
        .with_graceful_shutdown(signal)
        .await
        .unwrap();
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    dotenv()?;
    let (visitor, admin, certs) = read_env()?;
    let ports = get_ports();

    let handle = axum_server::Handle::new();
    let shutdown_future = shutdown(handle.clone());
    tokio::spawn(redirect_http_to_https(ports, shutdown_future));

    let config = RustlsConfig::from_pem_file(
        PathBuf::from(&certs).join("cert.pem"),
        PathBuf::from(&certs).join("key.pem"),
    )
    .await?;

    let app = create_routes(admin, visitor).await?;
    let addr = SocketAddr::from(([0, 0, 0, 0], ports.https));
    tracing::debug!("listening on {addr}");
    axum_server::bind_rustls(addr, config)
        .handle(handle)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}
