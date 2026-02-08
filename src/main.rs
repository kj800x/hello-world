use poem::{get, handler, listener::TcpListener, Route, Server};

#[handler]
fn hello() -> &'static str {
    "hello world"
}

#[handler]
fn healthcheck() -> &'static str {
    "ok"
}

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    #[cfg(unix)]
    unsafe {
        libc::signal(libc::SIGHUP, libc::SIG_IGN);
    }

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);

    tracing::info!("Starting server on {}", addr);

    let app = Route::new()
        .at("/", get(hello))
        .at("/healthcheck", get(healthcheck));

    Server::new(TcpListener::bind(addr)).run(app).await?;

    Ok(())
}
