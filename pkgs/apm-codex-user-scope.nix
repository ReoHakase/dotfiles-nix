{ apm }:

apm.overrideAttrs (old: {
  postPatch =
    (old.postPatch or "")
    + ''
      targets_file="$(find . -path '*/apm_cli/integration/targets.py' -print -quit)"
      pipeline_file="$(find . -path '*/apm_cli/install/pipeline.py' -print -quit)"
      test -n "$targets_file"
      test -n "$pipeline_file"

      # APM 0.9.2 defines Codex skills with deploy_root=".agents", but
      # omits user-scope support for the codex target. Enable skills-only
      # user-scope deployment so `apm install -g ... --target codex`
      # can write ~/.agents/skills.
      substituteInPlace "$targets_file" \
        --replace-fail '        auto_create=False,
        detect_by_dir=True,
    ),
}
' '        auto_create=False,
        detect_by_dir=True,
        user_supported="partial",
        user_root_dir=".codex",
        unsupported_user_primitives=("agents", "hooks"),
    ),
}
'

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
