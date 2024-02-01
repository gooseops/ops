# Goose Weather
The goal of this repository is to provide an easy-to-launch self-hosted weather application.

## Information
- Work in progress
## Quick start
### Prerequisites
- `python3` >= 3.10.12
    - See [docs](https://www.python.org/downloads/) for installation downloads for your OS.  Some OSs allow python3 installation through their package manager or come with a `python3` installation.  For example, Ubuntu comes with `python3` already installed, but you could install it with the following command:
    ```
    apt install python3.10
    ``` 
- `git`
    - See [docs](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for installation on your OS.  For example on Ubuntu:
    ```
    apt install git
    ```
- `venv` (`python3` standard library virtual envirnment tool)
    - See [docs](https://docs.docker.com/engine/) for installation on your OS.  Some `python3` installations do not come with `venv` module by default and you will need to install it separately. For example on Ubuntu:
    ```
    apt install python3.10-venv
    ```
### Process
- Clone the repository
    ```
    git clone https://github.com/gooseops/goose_weather.git
    ```
- Change directory to cloned repository
    ```
    cd goose_weather
    ```
- Create a virtual `python3` environment for this project to manage dependencies
    ```
    python3 -m venv .venv && source .venv/bin/activate
    ```
- Install pip packages
    ```
    pip3 install -r requirements.txt
    ```
- Run the server with `gunicorn`
    ```
    gunicorn -w 4 'app:app'
    ```
- Server should be running on [http://127.0.0.1:8000](http://127.0.0.1:8000) on your local machine.
## Launching with Docker
### Prerequisites
- `Docker`
    - See [docs](https://docs.docker.com/engine/install/) for installation on your OS.
### Process
- Launching from Docker Hub:
    ```
    docker run -p 8000:8000 gooseops/goose-weather:latest
    ```
- Building and launching locally:
    ```
    docker build -t goose-weather .
    docker run -p 8000:8000 goose-weather
    ```
- Server should be running on [http://127.0.0.1:8000](http://127.0.0.1:8000) on your local machine.
## Launching on Kubernetes
- Work in progress
<!-- ### Manifest
### Helm -->
