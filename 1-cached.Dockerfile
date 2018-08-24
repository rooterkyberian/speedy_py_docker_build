FROM python:3.7

RUN pip install pip==18.0 pipenv==2018.7.1

COPY Pipfile Pipfile.lock /app/
WORKDIR /app
RUN pipenv install --system  --deploy

COPY . /app

CMD python /app/hello
