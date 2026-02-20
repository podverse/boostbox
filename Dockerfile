# Local use only; this image is not published. Built from sibling repo via podverse Makefile.
# Multi-stage not required for local dev; single stage keeps deps cached when only src changes.
# Uses Clojure CLI; main-ns matches flake.nix (boostbox.boostbox).
FROM clojure:temurin-21-jammy

WORKDIR /app

# Layer deps so they are cached when only source changes.
COPY deps.edn deps-lock.json ./
RUN clojure -P

COPY src ./src

EXPOSE 8080

ENV ENV=DEV
ENV BB_STORAGE=FS
ENV BB_FS_ROOT_PATH=boosts

CMD ["clojure", "-M", "-m", "boostbox.boostbox"]
