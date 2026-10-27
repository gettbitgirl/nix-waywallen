{ lib }:
rec {
  # Parse git dependencies from a lito.lock file
  # Returns a list of { name, url, rev, source }
  parseLockGitDeps =
    lockFile:
    let
      lock = builtins.fromTOML (builtins.readFile lockFile);
      packages = lock.packages or [ ];
      allExternals = lib.flatten (map (p: p.externals or [ ]) packages);

      gitPackages = map (p: {
        inherit (p) name;
        source = p.source;
      }) (builtins.filter (p: lib.hasPrefix "git+" (p.source or "")) packages);

      gitExternals = map (e: {
        inherit (e) name;
        source = e.source;
      }) (builtins.filter (e: lib.hasPrefix "git+" (e.source or "")) allExternals);

      allGitSources = gitPackages ++ gitExternals;
    in
    map (
      g:
      let
        noGitPrefix = lib.removePrefix "git+" g.source;
        parts = lib.splitString "#" noGitPrefix;
        url = builtins.elemAt parts 0;
        rev = builtins.elemAt parts 1;
      in
      {
        inherit (g) name;
        inherit url rev;
        source = g.source;
      }
    ) allGitSources;

  # Generates flake inputs attribute set for a lito.lock file
  extractLockInputs =
    { lockFile, prefix }:
    let
      deps = parseLockGitDeps lockFile;
    in
    builtins.listToAttrs (
      map (d: {
        name = "${prefix}-${d.name}";
        value = {
          url = "git+${d.url}?rev=${d.rev}" + (if d.name == "qml-material" then "&lfs=1" else "");
          flake = false;
        };
      }) deps
    );

  # Extract compiler dependencies from lito's deps.json + lua
  extractCompilerInputs =
    { litoSrc, prefix ? "lito-dep" }:
    let
      deps = builtins.fromJSON (builtins.readFile "${litoSrc}/deps.json");
      depInputs = lib.mapAttrs' (
        name: dep: {
          name = "${prefix}-${name}";
          value = {
            url = "github:${dep.owner}/${dep.repo}/${dep.rev}";
            flake = false;
          };
        }
      ) deps;
    in
    depInputs
    // {
      "${prefix}-lua" = {
        url = "tarball+https://www.lua.org/ftp/lua-5.5.1.tar.gz";
        flake = false;
      };
    };

  # Resolve git dependencies for mkLitoBundle using flake inputs
  resolveGitDeps =
    {
      lockFile,
      prefix,
      inputs,
      overrides ? { },
    }:
    let
      deps = parseLockGitDeps lockFile;
      uniqueDeps = lib.foldl' (
        acc: d:
        if builtins.any (x: x.url == d.url) acc then
          acc
        else
          acc ++ [ d ]
      ) [ ] deps;
    in
    builtins.listToAttrs (
      map (
        d:
        let
          drv =
            if overrides ? ${d.name} then
              overrides.${d.name}
            else if overrides ? ${d.url} then
              overrides.${d.url}
            else if inputs ? "${prefix}-${d.name}" then
              inputs."${prefix}-${d.name}"
            else if inputs ? ${d.name} then
              inputs.${d.name}
            else
              throw "lito: Missing input for git dependency '${d.name}' (${d.url}). Expected inputs.${prefix}-${d.name}";
        in
        {
          inherit (d) name;
          value = drv;
        }
      ) uniqueDeps
    );
}
