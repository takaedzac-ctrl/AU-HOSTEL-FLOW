FROM dart:stable

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

CMD ["/app/bin/server"]

EXPOSE 8080
CMD ["/app/bin/server"]