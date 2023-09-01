
FROM node:19.5.0-alpine as frontendbuild


WORKDIR /app
COPY ./ /app

RUN npm ci

RUN npm run build

FROM nginx

COPY --from=frontendbuild app/dist /usr/share/nginx/html


