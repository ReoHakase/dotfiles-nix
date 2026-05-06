{ apm }:

apm.overrideAttrs (old: {
  postPatch =
    (old.postPatch or "")
    + ''
      pipeline_file="$(find . -path '*/apm_cli/install/pipeline.py' -print -quit)"
      test -n "$pipeline_file"

      # Work around microsoft/apm#830:
      # https://github.com/microsoft/apm/issues/830
      # In user scope, deploy root is $HOME; the existence of ~/.apm can
      # trigger local .apm integration and a broad recursive scan of $HOME.
      # The docs say local .apm content is skipped at --global scope, so
      # keep project-local .apm integration disabled for InstallScope.USER.
      substituteInPlace "$pipeline_file" \
        --replace-fail '    _root_has_local_primitives = _project_has_root_primitives(project_root)
' '    _root_has_local_primitives = (
        scope is not InstallScope.USER
        and _project_has_root_primitives(project_root)
    )
'
    '';
})
