# Enhanced commands.py with fzf integration and advanced features
# Custom commands for ranger file manager with fuzzy finding capabilities
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

from __future__ import (absolute_import, division, print_function)

# You can import any python module as needed.
import os
import subprocess
import shlex

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command


# Any class that is a subclass of "Command" will be integrated into ranger as a
# command.  Try typing ":my_edit<ENTER>" in ranger!
class my_edit(Command):
    # The so-called doc-string of the class will be visible in the built-in
    # help that is accessible by typing "?c" inside ranger.
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    # The execute method is called when you run this command in ranger.
    def execute(self):
        # self.arg(1) is the first (space-separated) argument to the function.
        # This way you can write ":my_edit somefilename<ENTER>".
        if self.arg(1):
            # self.rest(1) contains self.arg(1) and everything that follows
            target_filename = self.rest(1)
        else:
            # self.fm is a ranger.core.filemanager.FileManager object and gives
            # you access to internals of ranger.
            # self.fm.thisfile is a ranger.container.file.File object and is a
            # reference to the currently selected file.
            target_filename = self.fm.thisfile.path

        # This is a generic function to print text in ranger.
        self.fm.notify("Let's edit the file " + target_filename + "!")

        # Using bad=True in fm.notify allows you to print error messages:
        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        # This executes a function from ranger.core.acitons, a module with a
        # variety of subroutines that can help you construct commands.
        # Check out the source, or run "pydoc ranger.core.actions" for a list.
        self.fm.edit_file(target_filename)

    # The tab method is called when you press tab, and should return a list of
    # suggestions that the user will tab through.
    # tabnum is 1 for <TAB> and -1 for <S-TAB> by default
    def tab(self, tabnum):
        # This is a generic tab-completion function that iterates through the
        # content of the current directory.
        return self._tab_directory_content()


# ===================================================================
# == FZF Integration Commands
# ===================================================================

class fzf_select(Command):
    """:fzf_select
    
    Direct fzf file finder with preview (like nff bash function).
    """
    
    def execute(self):
        import subprocess
        
        # Use fd if available for better performance
        if os.system("command -v fd >/dev/null 2>&1") == 0:
            find_cmd = "fd --type f --hidden --follow --exclude .git"
        else:
            find_cmd = "find . -type f -not -path '*/.*'"
        
        # Use bat for preview if available
        if os.system("command -v bat >/dev/null 2>&1") == 0:
            preview_cmd = "bat --color=always --style=numbers --line-range=:500 {}"
        else:
            preview_cmd = "head -50 {}"
        
        cmd = [
            'bash', '-c',
            f'''{find_cmd} | fzf --height=50% --layout=reverse --border \
                   --preview="{preview_cmd}" --preview-window=right:50%:wrap \
                   --header='Select file to navigate to' \
                   --bind 'enter:become(echo {{}})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if result.returncode == 0 and result.stdout.strip():
                selected_file = result.stdout.strip()
                if os.path.exists(selected_file):
                    self.fm.select_file(selected_file)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("fzf_select error: {}".format(str(e)), bad=True)


class fzf_search(Command):
    """:fzf_search [query]
    
    Search file contents using ripgrep + fzf with live preview.
    """
    
    def execute(self):
        query = self.rest(1) or ''
        
        # Use ripgrep with fzf for content search
        cmd = [
            'bash', '-c',
            '''RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
               fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                   --ansi --disabled --query="''' + query + '''" \
                   --height=50% --layout=reverse \
                   --delimiter ':' \
                   --preview 'bat --color=always --highlight-line {2} {1}' \
                   --preview-window '+{2}/2' \
                   --bind 'enter:become(echo {1})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if result.returncode == 0 and result.stdout.strip():
                selected_file = result.stdout.strip()
                if os.path.exists(selected_file):
                    self.fm.select_file(selected_file)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("fzf_search error: {}".format(str(e)), bad=True)


class fzf_directories(Command):
    """:fzf_directories
    
    Direct fzf directory navigation (like nf bash function).
    """
    
    def execute(self):
        import subprocess
        
        # Use fd if available for better performance
        if os.system("command -v fd >/dev/null 2>&1") == 0:
            find_cmd = "fd --type d --hidden --follow --exclude .git"
        else:
            find_cmd = "find . -type d -not -path '*/.*'"
            
        cmd = [
            'bash', '-c',
            f'''{find_cmd} | fzf --height=50% --layout=reverse --border \
                   --preview='ls -la {{}} | head -20' --preview-window=right:50%:wrap \
                   --header='Select directory to navigate to' \
                   --bind 'enter:become(echo {{}})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                selected_dir = result.stdout.strip()
                if os.path.isdir(selected_dir):
                    self.fm.cd(os.path.abspath(selected_dir))
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("fzf_directories error: {}".format(str(e)), bad=True)


class fzf_bookmarks(Command):
    """:fzf_bookmarks
    
    Quick navigation to bookmarked directories using fzf.
    """
    
    def execute(self):
        bookmarks = {
            'Home': os.path.expanduser('~'),
            'Downloads': os.path.expanduser('~/Downloads'),  
            'Projects': os.path.expanduser('~/Projects'),
            'Documents': os.path.expanduser('~/Documents'),
            'Pictures': os.path.expanduser('~/Pictures'),
            'Videos': os.path.expanduser('~/Videos'),
            'Config': os.path.expanduser('~/.config'),
            'Chezmoi': os.path.expanduser('~/.local/share/chezmoi'),
            'NixOS': os.path.expanduser('~/system_nixos'),
            'Android': os.path.expanduser('~/AndroidStudioProjects'),
            'Root': '/',
            'Etc': '/etc',
            'Tmp': '/tmp'
        }
        
        # Create choices for fzf
        choices = []
        for name, path in bookmarks.items():
            if os.path.exists(path):
                choices.append("{}:{}".format(name, path))
        
        if not choices:
            self.fm.notify("No valid bookmarks found", bad=True)
            return
            
        cmd = ['echo'] + choices + ['|', 'fzf', '--delimiter', ':', '--with-nth', '1', 
               '--preview', 'ls -la {2} | head -20', '--bind', 'enter:become(echo {2})']
        
        try:
            result = subprocess.run(' '.join(cmd), shell=True, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                selected_path = result.stdout.strip()
                if os.path.isdir(selected_path):
                    self.fm.cd(selected_path)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("fzf_bookmarks error: {}".format(str(e)), bad=True)


# ===================================================================
# == Git Integration Commands
# ===================================================================

class git_log(Command):
    """:git_log
    
    Browse git log using fzf with preview.
    """
    
    def execute(self):
        if not os.path.exists('.git'):
            self.fm.notify("Not in a git repository", bad=True)
            return
            
        cmd = [
            'bash', '-c',
            '''git log --oneline --color=always | fzf --ansi \
                   --preview 'git show --color=always {1}' \
                   --bind 'enter:become(echo {1})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            if result.returncode == 0 and result.stdout.strip():
                commit_hash = result.stdout.strip()
                # Show the commit
                self.fm.execute_command("git show {}".format(commit_hash), flags='p')
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("git_log error: {}".format(str(e)), bad=True)


class git_status(Command):
    """:git_status
    
    Show git status with fzf navigation to changed files.
    """
    
    def execute(self):
        if not os.path.exists('.git'):
            self.fm.notify("Not in a git repository", bad=True)
            return
            
        cmd = [
            'bash', '-c',
            '''git status --porcelain | fzf --preview 'git diff --color=always {2}' \
                   --bind 'enter:become(echo {2})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                selected_file = result.stdout.strip()
                if os.path.exists(selected_file):
                    self.fm.select_file(selected_file)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("git_status error: {}".format(str(e)), bad=True)


class git_branch(Command):
    """:git_branch
    
    Switch git branches using fzf.
    """
    
    def execute(self):
        if not os.path.exists('.git'):
            self.fm.notify("Not in a git repository", bad=True)
            return
            
        cmd = [
            'bash', '-c',
            '''git branch -a | sed 's/^..//' | fzf --preview 'git log --oneline {1} | head -10' \
                   --bind 'enter:become(echo {1})'
            '''
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                branch = result.stdout.strip()
                # Checkout the branch
                checkout_result = subprocess.run(['git', 'checkout', branch], 
                                               capture_output=True, text=True)
                if checkout_result.returncode == 0:
                    self.fm.notify("Switched to branch: {}".format(branch))
                    self.fm.reload_cwd()
                else:
                    self.fm.notify("Failed to checkout branch: {}".format(branch), bad=True)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("git_branch error: {}".format(str(e)), bad=True)


# ===================================================================
# == Archive and File Operations
# ===================================================================

class extract(Command):
    """:extract [archive]
    
    Extract various archive formats.
    """
    
    def execute(self):
        if self.arg(1):
            archive = self.rest(1)
        else:
            archive = self.fm.thisfile.path
            
        if not os.path.exists(archive):
            self.fm.notify("File does not exist: {}".format(archive), bad=True)
            return
            
        # Determine extraction command based on file extension
        ext = archive.lower()
        if ext.endswith(('.tar.gz', '.tgz')):
            cmd = ['tar', 'xzf', archive]
        elif ext.endswith(('.tar.bz2', '.tbz2')):
            cmd = ['tar', 'xjf', archive]  
        elif ext.endswith('.tar.xz'):
            cmd = ['tar', 'xJf', archive]
        elif ext.endswith('.tar'):
            cmd = ['tar', 'xf', archive]
        elif ext.endswith('.zip'):
            cmd = ['unzip', archive]
        elif ext.endswith('.rar'):
            cmd = ['unrar', 'x', archive]
        elif ext.endswith('.7z'):
            cmd = ['7z', 'x', archive]
        else:
            self.fm.notify("Unsupported archive format: {}".format(archive), bad=True)
            return
            
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            if result.returncode == 0:
                self.fm.notify("Extracted: {}".format(archive))
                self.fm.reload_cwd()
            else:
                self.fm.notify("Extraction failed: {}".format(result.stderr), bad=True)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.fm.notify("Extract error: {}".format(str(e)), bad=True)


class bulk_rename(Command):
    """:bulk_rename
    
    Bulk rename selected files using your default editor.
    """
    
    def execute(self):
        import tempfile
        
        # Get selected files or current file
        if self.fm.thistab.get_selection():
            selected = self.fm.thistab.get_selection()
        else:
            selected = [self.fm.thisfile]
            
        if not selected:
            self.fm.notify("No files selected", bad=True)
            return
            
        # Create temporary file with current filenames
        with tempfile.NamedTemporaryFile(mode='w+', suffix='.txt', delete=False) as temp:
            temp_file = temp.name
            for f in selected:
                temp.write(os.path.basename(f.path) + '\n')
                
        # Edit the file
        editor = os.environ.get('EDITOR', 'vi')
        subprocess.run([editor, temp_file])
        
        # Read back the new names
        try:
            with open(temp_file, 'r') as f:
                new_names = [line.strip() for line in f.readlines()]
                
            if len(new_names) != len(selected):
                self.fm.notify("Number of lines doesn't match selected files", bad=True)
                return
                
            # Perform renames
            for old_file, new_name in zip(selected, new_names):
                if new_name and new_name != os.path.basename(old_file.path):
                    old_path = old_file.path
                    new_path = os.path.join(os.path.dirname(old_path), new_name)
                    try:
                        os.rename(old_path, new_path)
                    except OSError as e:
                        self.fm.notify("Rename failed {}: {}".format(old_path, str(e)), bad=True)
                        
            self.fm.reload_cwd()
            
        finally:
            # Clean up temp file
            os.unlink(temp_file)
