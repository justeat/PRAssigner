FROM swift:5.3-amazonlinux2
LABEL description="Docker Container for PR Assigner infrastructure management"

RUN yum -y install zip \
    unzip \
    jq

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

RUN unzip awscliv2.zip

RUN ./aws/install

RUN curl -o- -L https://slss.io/install | bash
