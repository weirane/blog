---
title: Status
author_profile: false
sidebar:
  nav: false
noindex: true
---

<dl>
  <dt>Build time</dt>
  <dd><time id="build-time" datetime="{{ site.time | date: "%F %T %z" }}">{{ site.time | date: "%F %T %z" }}</time></dd>
  <dt>Git commit</dt>
  <dd>
    <a href="https://github.com/{{ site.repository }}/commit/{{ site.git.last_commit.long_sha }}"><code>{{ site.git.last_commit.short_sha }}</code></a>
    {{ site.git.last_commit.message | newline_to_br | strip_newlines | split: '<br />' | first | xml_escape }}
  </dd>
  {% if site.env.GITHUB_RUN_NUMBER %}
  <dt>GitHub Actions <a href="https://github.com/weirane/blog/actions"><img src="https://github.com/weirane/blog/workflows/build/badge.svg" alt="Build Status" /></a></dt>
  <dd><a href="https://github.com/weirane/blog/actions/runs/{{ site.env.GITHUB_RUN_ID }}">Build {{ site.env.GITHUB_RUN_NUMBER }}</a></dd>
  {% endif %}
</dl>
