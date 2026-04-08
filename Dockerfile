FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/*.json /app/
COPY --from=build /app/au_hostel_flow.db /app/
WORKDIR /app
CMD ["/app/bin/server"]

EXPOSE 8080
CMD ["/app/bin/server"]