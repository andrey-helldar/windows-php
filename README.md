# Windows PHP Helper

## PHP versions

* 8.5
* 8.4
* 8.3
* 8.2

## Directory structure

- **your_folder**
    - **windows-php** _// this reposotory_
        - **bin** _// main executables_
            - **<dir_by_php_version>**
                - **activate.cmd**
                - **update.cmd**
        - **config** _// PHP configuration files_
        - **shell** _// Additional executables_
    - **modules**
        - _// php and other services and utils_

## File designations

    bin/X.X/activate.cmd  - Sets the required PHP version by default.
                              If not, download and install.

    bin/X.X/update.cmd    - Sets the required PHP version by default.
                              A fresh version of PHP will be forcibly downloaded and installed.

When downloading PHP, the script will also download and install the `php_redis`, `php_xdebug`, `imagick` and `rdkafka`
extensions.

## Using

1. Specify the link to the PHP folder in the environment variables. For example, `c:\dev\modules\php` (this is a symlink
   in PHP).
2. Create links to the files you need from the `bin` folder in a place convenient for you.
3. Run the links you need and use 😊

## Updating this project

- Open a command prompt;
- Go to the project directory;
- Execute the `git pull` command.
