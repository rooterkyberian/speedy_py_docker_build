FROM python:3.7

RUN pip install pip==18.0 pipenv==2018.7.1

COPY . /app
WORKDIR /app

RUN pipenv install --system --deploy

CMD python /app/hello
