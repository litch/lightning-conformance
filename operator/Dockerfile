FROM node:16.18.0-buster as build

WORKDIR /app/client
COPY ./client/package.json ./
COPY ./client/yarn.lock ./
RUN yarn install --production --frozen-lockfile
COPY ./client ./
RUN yarn run build

FROM python:3.10.8-slim-buster
WORKDIR /app/server
ENV PYTHONPATH "${PYTHONPATH}:/app"

COPY server/requirements.txt .
RUN pip install -r requirements.txt

COPY ./server ./

RUN rm ./config/nodes.ini

COPY --from=build /app/client/build/ ./static/

EXPOSE 5000

CMD ["gunicorn", "-b", ":5000", "graph_server.app:app"]

# CMD python3 graph_server/app.py
