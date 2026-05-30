---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "NamedSignal"
  text: "Documentation"
  tagline: "A Luau signal implementation with a nice balance of ergonomics, performance, and features."
  image: "logo.png"
  actions:
    - theme: brand
      text: Get Started
      link: getting-started/introduction
    - theme: alt
      text: API Reference
      link: api-reference/api-overview

features:
  - title: Rich Autofill
    details: Get named parameters in your anonymous function autofill.
    link: getting-started/quick-start#connect-a-listener
  - title: Strict Typing
    details: Fully strictly typed for the New Luau Type Solver.
    link: api-reference/api-overview#types
  - title: Deferred Mutations
    details: Queue actions during fire for predictability and consistency.
    link: api-reference/deferred-mutations
  - title: High Performance
    details: More efficient than engine APIs by working in pure Luau.
    link: additional-info/performance
---

## Yet *Another* Signal Library?<!-- markdownlint-disable-line MD041 -->

I suppose so! I built NamedSignal out of frustration because other libraries just didn't have the DX I was looking for.

Over time, I've expanded NamedSignal to be **more reliable and convenient**, as well as **fixing long-standing bugs** that are *still* present in other popular libraries, such as the dreaded `cannot resume non-suspended coroutine`/`cannot spawn non-suspended coroutine with arguments` error, and many more improvements!

Check out the various documentation pages to **learn what sets NamedSignal apart from the others**.
