FROM python:3.7-slim

RUN pip install pip==18.0 pipenv==2018.7.1

COPY Pipfile Pipfile.lock /app/
WORKDIR /app

ARG DEV=false
RUN if [ "$DEV" = "true" ]; then \
     echo "Dev dependencies enabled"; \
     pipenv install --system --deploy --dev; \
    else \
     pipenv install --system --deploy; \
    fi

COPY . /app

CMD python /app/hello
