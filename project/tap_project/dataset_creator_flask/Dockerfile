FROM python:3.8

MAINTAINER Cristofero Catania

EXPOSE 8081

WORKDIR /contents

ADD dataset_creator_flask.py .
ADD requirements.txt .


RUN python3 -m pip install --upgrade pip setuptools
RUN python3 -m pip install -r requirements.txt

CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8081", "dataset_creator_flask:app" ]