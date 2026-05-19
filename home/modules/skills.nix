_: {
  programs.agent-skills = {
    enable = true;

    sources = {
      mizchi = {
        input = "mizchi-skills";
        filter.maxDepth = 1;
      };
      ast-grep = {
        input = "ast-grep-agent-skill";
        subdir = "ast-grep/skills";
        filter.maxDepth = 1;
      };
      reohakase = {
        input = "reohakase-skills";
        filter.maxDepth = 1;
      };
    };

    skills.enable = [
      "empirical-prompt-tuning"
      "tech-article-reproducibility"
      "apm-usage"
      "nix-setup"
      "justfile"
      "dotenvx"
      "ast-grep"
      "conventional-commit"
      "agentskills-authoring"
    ];

    targets = {
      agents.enable = true;
      claude.enable = true;
      cursor.enable = true;
    };
  };
}
