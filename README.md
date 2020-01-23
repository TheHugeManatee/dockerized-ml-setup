# Installation/Setup notes - ML System with Docker

## Step 1 - Installed Ubuntu 18.04 LTS and host System and drivers
 - installed CUDA 10.1 from [official instructions](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1804&target_type=debnetwork)
    - this installed `nvidia-driver-440`
 - also installed some convenience programs and convenience things
    - vscode (supports python, jupyter, docker etc. through extensions)
    - [nvtop](https://github.com/Syllo/nvtop) - like htop but for GPU load
      ```bash
      sudo apt install cmake libncurses5-dev libncursesw5-dev git
      git clone https://github.com/Syllo/nvtop.git
      mkdir -p nvtop/build && cd nvtop/build
      cmake ..
      make
      sudo make install
      ```
## Step 2 - Install docker environment
 - installed Docker with convenience script
    ```bash
    $ curl -fsSL https://get.docker.com -o get-docker.sh
    $ sudo sh get-docker.sh
    ```
 - added current user to docker group for convenience: `sudo usermod -aG docker $USER`
 - installed `docker-compose`
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/1.25.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
   ```
 - installed nvidia container runtime from [this page](https://developer.nvidia.com/nvidia-container-runtime). 
    This is needed (?) to pass through the GPUs to docker. 
    More info [in this dev blog](https://devblogs.nvidia.com/gpu-containers-runtime/) (also shows how to enable graphics support).
    - followed [this guide](http://collabnix.com/introducing-new-docker-cli-api-support-for-nvidia-gpus-under-docker-engine-19-03-0-beta-release/)
    - `sudo apt-get install nvidia-container-runtime`
    - had to restart docker service `sudo systemctl restart docker`
    - verify it works: `docker run -it --rm --gpus all debian`, this should NOT show a *"could not select device driver"* error
 - added nvidia runtime to docker by editing/creating `/etc/docker/daemon.json` (and restart docker daemon again)
   ```json
   {
      "runtimes": {
         "nvidia": {
               "path": "nvidia-container-runtime",
               "runtimeArgs": []
         }
      }
   }
   ```
## Step 3 - Set up a working project
 - pulled the [optimized nvidia pytorch container](https://ngc.nvidia.com/catalog/containers/nvidia:pytorch)
    ```bash
    docker pull nvcr.io/nvidia/pytorch:19.12-py3
    ```
 - they suggest using the following command for an interactive session:
    ```bash
    docker run --gpus all -it --rm -v local_dir:container_dir nvcr.io/nvidia/pytorch:xx.xx-py3
    ```

Instead, i like to setup my container as a more persistent container (as I like to install some additional libraries). For that, I use a slightly different setup:
 - I use a git repository to store all my source code and map this directly into my container into `/code`. This allows me to work on the code from the host side
 - I use a separate directory for (large) training data which I map to `/data` in the container
 - I use a `Dockerfile` to set up my default container to already have some python packages installed, and automatically start a jupyter instance:
    ```Dockerfile
    FROM nvcr.io/nvidia/pytorch:19.12-py3
    WORKDIR /code
    RUN pip install fastai
    #CMD ["/bin/bash"]
    CMD ["jupyter", "notebook"]
    ```
 - I use a docker-compose file to start up the container:
    ```yml
    version: '2.3'
    services:
    jupyter:
        build: .
        container_name: mlenv
        runtime: nvidia
        volumes:
        - /home/TheHugeManatee/my_project/:/code
        - /home/TheHugeManatee/data/:/data
        ports:
        - "8888:8888"
        environment:
        - NVIDIA_VISIBLE_DEVICES=all
    ```
    **Note**: seemingly, the `runtime` option only works with `version: '2.3'`, **NOT** with `version: '3'`.

To work on my project and code/train, run `docker-compose up`, then copy the url from the console window into the browser on the host system to start using jupyter.


## For more convenience:
   - add `restart: always` to the `jupyter` service in the docker-compose - this will auto-start the jupyter server on system startup
   - jupyter will re-generate a new token on every restart. To get the token, you can check the command `docker logs mlenv` on your host.
   - alternatively, you can set a fixed password: 

        Generate the hash with the following code:
        ```python
        from notebook.auth import passwd
        passwd()
        ```
        Then, modify your `Dockerfile` CMD line:
        ```Dockerfile
        CMD ["jupyter", "notebook", "--notebook-dir=/code", "--NotebookApp.password='sha1:c7e6e0960789:076aa53621717f7be7eede61a95fd9772ec74784'"]
        ```
        After this, you will have to rebuild your docker image with `docker-compose up --build`

    Note the considerations [documented here](https://jupyter-notebook.readthedocs.io/en/stable/security.html)
   - [this blog post](https://ljvmiranda921.github.io/notebook/2018/01/31/running-a-jupyter-notebook/) might be interesting to safely enable remote access