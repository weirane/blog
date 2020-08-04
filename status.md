---
layout: single
title: Status
permalink: /status/
noindex: true
---

<dl>
  <dt>Build time</dt>
  <dd><time id="build-time" datetime="{{ site.time | date: "%F %T" }}">{{ site.time | date: "%F %T" }}</time></dd>
  <dt>Git commit</dt>
  <dd>
    <a href="https://github.com/{{ site.repository }}/commit/{{ site.git.last_commit.long_sha }}"><code>{{ site.git.last_commit.short_sha }}</code></a>
    {{ site.git.last_commit.message | newline_to_br | strip_newlines | split: '<br />' | first | xml_escape }}
  </dd>
  {% if site.env.TRAVIS_BUILD_ID %}
  <dt>Travis CI</dt>
  <dd><a href="https://travis-ci.org/{{ site.repository }}/builds/{{ site.env.TRAVIS_BUILD_ID }}">Build {{ site.env.TRAVIS_BUILD_NUMBER }}</a></dd>
  {% endif %}
</dl>
