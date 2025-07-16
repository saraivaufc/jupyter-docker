FROM tensorflow/tensorflow:2.19.0-gpu-jupyter

LABEL saraivaufc <www.saraiva.dev>

WORKDIR /opt

RUN apt-get -qq update -y

RUN apt-get -qqy install axel openssh-server openssh-client sudo \
    python3-dev python3-pip \
    libgdal-dev gdal-bin \
    graphviz \
    openjdk-17-jdk \
    scala

RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# SSH Keys
RUN mkdir -p /root/.ssh/
COPY ./ssh_keys/* /root/.ssh/
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 0600 /root/.ssh/id_rsa
RUN /usr/bin/ssh-keygen -A

# To download Spark
RUN axel https://archive.apache.org/dist/spark/spark-4.0.0/spark-4.0.0-bin-hadoop3.tgz
RUN tar -xvzf spark-4.0.0-bin-hadoop3.tgz
RUN mv spark-4.0.0-bin-hadoop3 ./spark
RUN rm spark-4.0.0-bin-hadoop3.tgz

# To update pip
RUN pip3 install --upgrade pip

# To Install Tensorflow WSL2
RUN pip3 install tensorflow[and-cuda]==2.19.0

# To download PySpark
RUN pip3 install pyspark==4.0.0

# To Install Scala Kernel to Jupyter
RUN pip3 install spylon-kernel
RUN python3 -m spylon_kernel install

# To install GDAL
RUN pip3 install numpy
RUN pip3 install GDAL==$(gdal-config --version) --global-option=build_ext --global-option="-I/usr/include/gdal"

# To Install Other required Python packages
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# Configure Jupyter
RUN mkdir notebook
RUN mkdir -p /root/.jupyter

# BASH FILES
COPY ./bash_files/* /root/

# COPY ENVIROMENT VARIABLES
COPY ./spark-env.sh ./spark/conf/
COPY ./spark-defaults.conf ./spark/conf/
COPY ./getGpusResources.sh ./spark/conf/

# ENTRYPOINT
COPY ./docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]

# PORTS

EXPOSE 7077 8080 22 4040 8998

# Expose Jupyter port
EXPOSE 8899