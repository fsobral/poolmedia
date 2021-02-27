# poolmedia
Web interface to the Nested Pool testing strategy for SARS-CoV-2

# Python server

The REST API is provided using the Python package
[Flask](https://flask.palletsprojects.com).

## Configuration file

This application requires some information to be given via
configuration file. The format of the file follows the
[configparser](https://docs.python.org/3/library/configparser.html)
documentation and is detailed below.

### `[Poolmedia]` section

  . `url.prefix`: the prefix to load the API. By default is `/`
  . `fortran.exec.name`: name of the Fortran executable. Default is `program.x`
  . `fortran.exec.path`: full path to the Fortran executable. Default is `./`
  . `logging.filename`: full path + base filename for the Rotating Log. Default is `./poolmedia.log`
  . `logging.level`: level of the log. Default is `INFO`. Options (from least to most verbose): `CRITICAL`, `ERROR`, `WARNING`, `INFO`, `DEBUG`
