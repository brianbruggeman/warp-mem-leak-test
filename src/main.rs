use warp::Filter;

// Controls address through environment varialbes
fn get_address() -> std::net::SocketAddr {
    dotenv::dotenv().ok();
    let host = std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = std::env::var("PORT").unwrap_or_else(|_| "3030".to_string());
    let netloc = format!("{}:{}", host, port);
    println!("[Warp App] Serving on: {}", &netloc);
    let default_socket = std::net::SocketAddr::new(
        std::net::IpAddr::V4(std::net::Ipv4Addr::new(127, 0, 0, 1)),
        8080,
    );
    netloc
        .parse::<std::net::SocketAddr>()
        .unwrap_or_else(|_| default_socket)
}

#[tokio::main]
async fn main() {
    let addr = get_address();

    // GET /hello/warp => 200 OK with body "Hello, warp!"
    let hello = warp::path!("hello" / String).map(|name| format!("Hello, {}!", name));

    warp::serve(hello).run(addr).await;
}
