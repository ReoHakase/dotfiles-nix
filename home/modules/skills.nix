_: {
  programs.agent-skills = {
    enable = true;

    sources = {
      mizchi = {
        input = "mizchi-skills";
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
      "nix-setup"
      "dotenvx"
      "conventional-commit"
      "github-issue-pr-ops"
      "agentskills-authoring"
      "minimum-impl"
    ];

    targets = {
      agents.enable = true;
      claude.enable = true;
      cursor.enable = true;
    };
  };
}
