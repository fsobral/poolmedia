import setuptools

# Long description of the project
with open("../README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="poolmedia_server-fsobral", # Replace with your own username
    version="0.0.1",
    author="FNC Sobral",
    author_email="fncsobral@uem.br",
    description="Package for providing RESTfull interactions with a Fortran package",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/poolmedia",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    data_files=[('fortran', 'poolmedia.for')],
)

from os import system

try:

    system('gfortran fortran/poolmedia.for -o fortran/poolmedia')

except Exception as e:

    raise Exception('Unable to compile the fortran program.')
