use std::collections::HashSet;

use lazy_static::lazy_static;


const CSV_STR: &str = include_str!("../countries.csv");

lazy_static! {
    static ref COUNTRIES_SET: HashSet<(&'static str, &'static str)> = {
        CSV_STR
            .split("\n")
            .skip(1)
            .map(|l| {
                let mut s = l.split(",");
                (s.nth(0).unwrap(), s.nth(1).unwrap())
            })
            .collect()
    };
}

fn validate_country_by_name(country: &str) -> bool {
    COUNTRIES_SET.iter().any(|(name, _)| (**name) == (*country))
}

fn validate_country_by_code(country_code: &str) -> bool {
    COUNTRIES_SET.iter().any(|(_, code)| *code == country_code)
}
