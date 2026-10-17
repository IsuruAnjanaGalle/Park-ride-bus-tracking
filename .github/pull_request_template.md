## Pull Request Description

### Summary of Changes
<!-- Provide a concise description of the motivation and features or bugfixes introduced. -->

### Related Issues
<!-- Link relevant issue numbers, e.g. Fixes #123 -->

---

## Type of Change
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Performance optimization / Refactoring
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Infrastructure / CI update

---

## Verification & Testing Checklist
- [ ] Jac models compile without type errors (`jac check core/...`)
- [ ] All tests in `tests/test_core.jac` pass cleanly (`jac test tests/test_core.jac`)
- [ ] Edge endpoint types are explicitly declared
- [ ] Trilingual localization strings updated if UI text was altered
- [ ] Documentation in `docs/` updated if API contracts changed
