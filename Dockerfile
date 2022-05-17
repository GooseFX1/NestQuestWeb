FROM rust:1.57

RUN apt-get update && apt-get install -y libudev-dev

COPY ./ ./

RUN cargo build  --release

CMD ["./target/release/nestquest"]
