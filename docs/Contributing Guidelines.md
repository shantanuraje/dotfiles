# Contributing Guidelines

Welcome to the dotfiles project! This document outlines how to contribute to and maintain this configuration setup.

## 🏗️ Project Structure

```
dotfiles/
├── docs/                      # Documentation (this directory)
├── private_dot_config/        # Application configurations
│   ├── awesome/              # AwesomeWM window manager
│   ├── hypr/                 # Hyprland compositor
│   ├── kitty/                # Terminal emulator
│   ├── polybar/              # Status bar
│   ├── rofi/                 # Application launcher
│   └── ...
├── system_nixos/             # NixOS system configuration
├── system_scripts/           # Deployment and utility scripts
└── dot_*                     # Shell and system dotfiles
```

## 🛠️ Development Workflow

### Making Changes

1. **Test First**: Always test changes in a safe environment
2. **Document Changes**: Update relevant documentation in `docs/`
3. **Follow Conventions**: Maintain consistent code style and structure
4. **Update Archives**: Move outdated docs to `docs/archive/`

### Configuration Management

- Use **chezmoi** for dotfiles management
- Follow the `private_dot_*` naming convention for private files
- Keep sensitive information out of version control

### Deployment

- Use `system_scripts/deploy-nixos.sh` for NixOS deployments
- Test with `system_scripts/test-deploy-nixos.sh` first
- Run `system_scripts/auto-detect-machine.sh` to identify system type

## 📝 Documentation Standards

### Structure
- Use **Obsidian MOC** style for navigation
- Cross-link related documents with `[[Document Name]]`
- Organize by category: `polybar/`, `system/`, `project/`, `archive/`

### Writing Style
- Use clear, concise language
- Include code examples with syntax highlighting
- Add emoji icons for visual organization
- Maintain consistent formatting

### Updates
- Keep documentation in sync with code changes
- Move outdated content to `docs/archive/`
- Update the main MOC (`docs/README.md`) when adding new docs

## 🔧 Technical Guidelines

### Code Quality
- Comment complex configurations
- Use meaningful variable names
- Follow language-specific conventions
- Test changes before committing

### Compatibility
- Ensure changes work across different machines
- Test on both personal and work environments
- Maintain backward compatibility when possible

### Security
- Never commit sensitive information
- Use chezmoi templates for machine-specific configs
- Keep work-specific configurations separate

## 🐛 Issue Management

### Bug Reports
1. Check existing issues first
2. Provide detailed reproduction steps
3. Include system information
4. Attach relevant log files

### Feature Requests
1. Describe the use case clearly
2. Explain the expected behavior
3. Consider implementation complexity
4. Discuss potential breaking changes

## 📋 Maintenance Tasks

### Regular Updates
- Update package lists in NixOS configurations
- Review and update documentation
- Test configurations on new system versions
- Archive outdated documentation

### Cleanup
- Remove unused configurations
- Clean up old backup files
- Update broken links in documentation
- Optimize performance where possible

## 🚀 Release Process

### Pre-Release
1. Test all critical functionality
2. Update version numbers where applicable
3. Review and update documentation
4. Create deployment backup

### Release
1. Tag the release appropriately
2. Update main README.md if needed
3. Deploy to target systems
4. Monitor for issues

### Post-Release
1. Address any immediate issues
2. Update documentation with lessons learned
3. Plan next iteration improvements
4. Archive old documentation if needed

## 📚 Learning Resources

### Essential Tools
- **chezmoi**: Dotfiles management
- **NixOS**: System configuration
- **AwesomeWM**: Window manager
- **Hyprland**: Wayland compositor
- **Polybar**: Status bar configuration

### Documentation
- [[Installation Guide]] - Getting started
- [[docs/README]] - Main documentation index
- [[NixOS Configuration]] - System setup
- [[Polybar Overview]] - Status bar configuration

## 💡 Tips for Contributors

### Best Practices
- Start with small, focused changes
- Test thoroughly before submitting
- Document your changes clearly
- Ask questions when unsure

### Common Pitfalls
- Don't modify archived documentation
- Avoid breaking existing functionality
- Don't commit sensitive information
- Don't skip testing steps

### Getting Help
- Review existing documentation first
- Check the archive for historical context
- Test changes in isolated environments
- Document solutions for future reference

---

*This is a living document. Update it as the project evolves and new workflows are established.*
