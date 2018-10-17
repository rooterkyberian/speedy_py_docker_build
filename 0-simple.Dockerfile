FROM python:3.7

RUN pip install pip==18.1 pipenv==2018.10.13

COPY . /app
WORKDIR /app

RUN pipenv install --system --deploy

CMD python /app/hello
