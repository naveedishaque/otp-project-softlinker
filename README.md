# otp-project-softlinker
A perl script to create a softlink structure for analysing data processed by the One Touch Pipeline (OTP)

## Prerequisites

- A working OTP setup, and project data to link to
- Developed using perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi
- Perl library Perl::DateTime and Getopt::Long

## conda setup

`conda install perl=5.26.2 perl-datetime=1.42 perl-getopt-long=2.50`

## Usage

```
  perl otp-project-softlinker.pl
           -i /path/to/project_dir
           -o /path/to/analysis_dir
           -p list_of_pids
           -h 
```

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

 - v1.0.0: first working version (equivalent to v0.7) 

## Authors

Naveed Ishaque

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
