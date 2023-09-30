# Doing multi-version Ruby on Rails development in a linux VM.

## Phase 1, the VM.
(easy)

1. Check that on the host the CPU support for virtualisation is enabled in BIOS/UEFI.
    AMD: "AMD-v" / "SVM"        or Intel:  VT-x / "VMX"

2. Install virtualisation software, e.g. VirtualBox 6.1+

3. Get desktop version of OS installer ISO. e.g. mint 20.3 64 bit

4. Create guest VM. 
  * In Settings / System / Advanced tab, ensure PAE/NX is enabled (allows 64 bit).
  * For portability the VM can be created on a fast USB3 flash drive. Built-in SSD is faster.
  * When creating the virtual harddrive, a 20GB size is basically the minium these days.
  * I accept VirtualBox's default VHD format, but depends on how far ahead & portable is needed.

5. Mount OS ISO as optical in VM.

6. Boot the VM, install OS with defaults,
     e.g. the wipe disk and create new partitions.
     change OS package mirror to local server, etc.

## Phase 2, VM OS setup.
(easy)

1. Uninstall any desktop applications you are not going to use to save space.

2. Do a package update of anything network or application security bug related.

3. Install the virtualbox guest addition packages: virtualbox-guest-utils, virtualbox-guest-x11

4. Shutdown the VM and restart it to ensure virtualbox additions are working in guest.

5. Install NoScript and CAD extensions for Firefox, just in case sometimes you need to launch a link from within the VM, but usually it is better to browse documentation and web outside the VM.

6. Do an OS shutdown, then take a snapshot of the VM virtual harddrive. Annotate with something informative like "OS was set up"


## Phase 3, Developer Tools setup.
(quirky and fiddly)
1. Install git and then run the `git config --global` to set up.
   1. `git config --global --add user.name "My Name"`
   2. `git config --global --add user.email "my.email@example.com"`
   3. git remote repo credentials: Optionally copy your github SSH private key into `~/.ssh/` so can then use `ssh-agent` and `ssh-add ~/.ssh/id_ed25519` for authentication to GH.

2. Install a ruby version manager such as rbenv. https://github.com/rbenv/rbenv#basic-git-checkout
   0. Uninstall the OS package manager's ruby-build and rbenv as they are probably outdated.
   1. `git clone https://github.com/rbenv/rbenv.git ~/.rbenv`
   2. `git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build`

3. Install a ruby version supported by Ruby-LSP, in this case 3.2.2 was used, plus extras.
   1. `sudo apt-get install libyaml`
   2. `sudo apt-get install libffi`
   3. `gem install psych`
   4. `rbenv install 3.2.2`
   5. `rbenv global 3.2.2`
   6. Install bundler package. For each ruby version,  
      activate it in shell with `rbenv shell _version_` then run `gem install bundle` .

4. Get the linux installer .tar.gz for openjdk, check the message digest, and unpack.  
   This can go under the developer user's home directory. e.g. in `~` these commands...
   1. `sha256sum ./Downloads/openjdk-21_linux-x64_bin.tar.gz`
   2. `tar --extract -f ./Downloads/openjdk-21_linux-x64_bin.tar.gz -z`
   
   ...would create `~/jdk-21/` java home because of the folder built in to the archive.

5. VS Code Installation.
   0. Get the linux installer (.deb in this case) for VS Code. Can be downloaded within the VM with firefox or curl if you copy the URL from [the Microsoft site](https://code.visualstudio.com/Download).
   1. Install VS Code using GDebi or similar.

6. Start VS Code and install language related extensions.
  * "Ruby LSP" from Shopify.
  * "VSCode **rdbg** Ruby Debugger" from Koichi Sasada.
  * "Python" from Microsoft.
  * "Extension Pack for Java" from Microsoft.

## Setup for Ruby LSP / VS Code and rbenv which has to be done per project.

1. `cd` to the project code root dir. This is the one with Gemfile in it.
2. Ensure the `.ruby-version` file is created naming the right version, with e.g. `rbenv local 1.2.3` .
3. run `bundle install` to setup all packages required for that project (from Gemfile).
4. Create a folder (e.g. `dev-config`) as a sibling to the project root folder for holding the Ruby LSP Gemfile
5. Create a Gemfile with the content suggested by the Ruby-LSP project repo. ie
   ```
    source "https://rubygems.org"
    git_source(:github) { |repo| "https://github.com/#{repo}.git" }

    ruby "3.2.2"

    group :development, :test do
      # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
      gem "ruby-lsp", require: false
      gem "debug", platforms: %i[ mri mingw x64_mingw ]
    end
   ```
6. Create a `.ruby-version` file in the same dir with just 3.2.2 on the first line.
7. switch to ruby 3 (`rbenv shell 3.2.2`), go to the `dev-config` folder, then run `bundle install` there.
8. (Potential) I had a problem with a version of 'io-console' 5.10 missing from the rubygems site, but this may not be a reoccurring problem. My workaround was to hack the `Gemfile.lock` and change which version it depended on from 5.10 to 5.11, then re-run `bundle install`
9.  Start VS Code and open the project source root folder. Create `launch.json` entries for rdbg.
    * The simple debug with dbg launch will work for simple ruby programs.
    * The example given for rdbg on https://code.visualstudio.com/docs/languages/ruby will work for Rails tests

    1. Go to the Run/Debug view.
    2. In the top of that pane click the drop-down box and pick Create launch json...
    3. Type 'rdbg' to narrow the search and pick Debug with rdbg
    4. Whatever it generates can be customised according to microsoft's suggestion:
       ```json
        {
            "type": "rdbg",
            "name": "rdbg Debug current file",
            "request": "launch",
            "script": "${file}",
            "args": [],
            "askParameters": true
        },
        {
            "name": "Minitest Rails with current file",
            "type": "rdbg",
            "request": "launch",
            "command": "${workspaceRoot}/bin/rails",
            "script": "test",
            "args": ["${file}:${lineNumber}"],
            "askParameters": false
        },
       ```
10. Test debugging by:
    * using rdbg "rdbg Debug current file" to step through a simple Hello World program. OR
    * using rdbg "Minitest Rails with current file" to debug a unit test with Rails packages loaded.


