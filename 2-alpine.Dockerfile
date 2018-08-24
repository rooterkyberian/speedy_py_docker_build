FROM python:3.7-alpine

RUN pip install pip==18.0 pipenv==2018.7.1

# stuff required for C extensions (namely: pandas)
RUN apk add --no-cache --virtual=build_dependencies \
    musl-dev gcc python-dev make cmake g++ gfortran && \
    apk add --no-cache libstdc++ && \
    ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY Pipfile Pipfile.lock /app/
WORKDIR /app
RUN pipenv install --system  --deploy

RUN apk del build_dependencies

COPY . /app

CMD python /app/hello
