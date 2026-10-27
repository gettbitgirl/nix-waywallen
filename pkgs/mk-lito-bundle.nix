{
  lib,
  runCommandLocal,
  fetchurl,
}:
{
  # Path to lito.lock (e.g. "${src}/lito.lock")
  lockFile,
  # Target platform system string (e.g. "x86_64-linux")
  system ? null,
  # Optional overrides for git dependencies, keyed by repo URL or package name
  gitOverrides ? { },
  # Git dependencies provided directly (e.g. from flake inputs or resolver)
  gitDeps ? { },
  # List of CMake package names to override with system/installed versions (e.g. [ "glslang" "Eigen3" ])
  cmakeOverrides ? [ ],
  # List of search paths for tools.cmake
  cmakeSearchPaths ? [ ],
  # List of git dependency names to skip resolving (e.g. because they are overridden with cmakeOverrides)
  ignoredGitDeps ? [ ],
  # Base registry URL (defaults to upstream litocpp registry)
  registryUrl ? "https://registry.litocpp.org/",
}:
let
  lock = builtins.fromTOML (builtins.readFile lockFile);
  packages = lock.packages or [ ];

  systemArch =
    if system == null then
      "x86_64"
    else if lib.hasPrefix "x86_64" system then
      "x86_64"
    else if lib.hasPrefix "aarch64" system then
      "aarch64"
    else
      "x86_64";

  # 1. Registry packages
  isRegistryPkg = p: lib.hasPrefix "registry+" (p.source or "");
  registryPkgs = builtins.filter isRegistryPkg packages;

  resolvedRegistryPkgs = map (
    p:
    let
      name = p.name;
      version = p.version;
      checksum = p.checksum;
      hashPrefix = builtins.substring 0 16 checksum;
      filename = "${name}-${version}-${hashPrefix}.tar.zst";

      regBase = if p ? source then lib.removePrefix "registry+" p.source else registryUrl;
      base = if lib.hasSuffix "/" regBase then regBase else "${regBase}/";
      url = "${base}packages/${name}/${name}-${version}.tar.zst";

      drv = fetchurl {
        inherit url;
        sha256 = checksum;
      };
    in
    {
      inherit filename drv;
    }
  ) registryPkgs;

  # 2. External archives
  allExternals = lib.flatten (map (p: p.externals or [ ]) packages);
  archiveExternals = builtins.filter (e: lib.hasPrefix "archive+" (e.source or "")) allExternals;

  isMatchingArchive =
    a:
    let
      url = lib.removePrefix "archive+" a.source;
      arches = a.architectures or [ ];
      matchesArch = arches == [ ] || builtins.elem systemArch arches;
      # Filter out foreign OS platforms if compiling for linux
      matchesOs =
        if system != null && lib.hasSuffix "-linux" system then
          (!lib.hasInfix "macos" url && !lib.hasInfix "windows" url)
        else
          true;
    in
    matchesArch && matchesOs;

  matchingArchives = builtins.filter isMatchingArchive archiveExternals;

  resolvedArchives = map (
    a:
    let
      url = lib.removePrefix "archive+" a.source;
      checksum = a.checksum;
      key = builtins.hashString "sha256" "lito-fetch-v1\narchive\n${url}\n${checksum}";
      drv = fetchurl {
        inherit url;
        sha256 = checksum;
      };
    in
    {
      inherit key drv;
    }
  ) matchingArchives;

  # 3. Git dependencies (from package sources and external sources)
  gitPackages = map (p: {
    inherit (p) name;
    source = p.source;
  }) (builtins.filter (p: lib.hasPrefix "git+" (p.source or "")) packages);

  gitExternals = map (e: {
    inherit (e) name;
    source = e.source;
  }) (builtins.filter (e: lib.hasPrefix "git+" (e.source or "")) allExternals);

  allGitSources = builtins.filter (
    g: !builtins.elem g.name ignoredGitDeps
  ) (gitPackages ++ gitExternals);

  resolvedGitDeps = map (
    g:
    let
      noGitPrefix = lib.removePrefix "git+" g.source;
      parts = lib.splitString "#" noGitPrefix;
      url = builtins.elemAt parts 0;
      rev = builtins.elemAt parts 1;
      name = g.name;

      drv =
        if gitOverrides ? ${name} then
          gitOverrides.${name}
        else if gitOverrides ? ${url} then
          gitOverrides.${url}
        else if gitDeps ? ${name} then
          gitDeps.${name}
        else if gitDeps ? ${url} then
          gitDeps.${url}
        else
          throw "mk-lito-bundle: Missing git dependency '${name}' (${url}). Please supply it via gitDeps or gitOverrides.";
    in
    {
      inherit name url drv;
    }
  ) allGitSources;

  # Deduplicate git dependencies by URL
  uniqueGitDeps = lib.foldl' (
    acc: g:
    if builtins.any (x: x.url == g.url) acc then
      acc
    else
      acc ++ [ g ]
  ) [ ] resolvedGitDeps;

  # 4. Generate source bundle derivation
  sourceBundle =
    runCommandLocal "lito-source-bundle" { } ''
      mkdir -p $out/v1/registry/source
      mkdir -p $out/v1/archives

      ${lib.concatMapStringsSep "\n" (p: ''
        cp ${p.drv} $out/v1/registry/source/${p.filename}
      '') resolvedRegistryPkgs}

      ${lib.concatMapStringsSep "\n" (a: ''
        mkdir -p $out/v1/archives/${a.key}
        cp ${a.drv} $out/v1/archives/${a.key}/source.archive
      '') resolvedArchives}
    '';

  # 5. Generate .lito/config.toml patch section
  cmakeOverridesToml = lib.concatMapStringsSep "\n\n" (pkg: ''
    [tools.cmake.overrides."${pkg}"]
    source = "installed"
  '') cmakeOverrides;

  cmakeSearchPathsToml = lib.optionalString (cmakeSearchPaths != [ ]) ''
    [tools.cmake]
    search-path = [
      ${lib.concatMapStringsSep "\n      " (p: ''"${p}",'') cmakeSearchPaths}
    ]
  '';

  configToml = lib.concatStringsSep "\n\n" (
    builtins.filter (s: s != "") [
      (lib.concatMapStringsSep "\n\n" (g: ''
        [patch."${g.url}"]
        path = "${g.drv}"
      '') uniqueGitDeps)
      cmakeOverridesToml
      cmakeSearchPathsToml
    ]
  );

  # Attrset of git deps by name: { wavsen = /nix/store/...; ... }
  gitDepsMap = builtins.listToAttrs (
    map (g: {
      name = g.name;
      value = g.drv;
    }) uniqueGitDeps
  );
in
{
  inherit
    sourceBundle
    configToml
    resolvedRegistryPkgs
    resolvedArchives
    uniqueGitDeps
    ;
  gitDeps = gitDepsMap;
}
