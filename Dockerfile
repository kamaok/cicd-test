FROM node:alpine

WORKDIR /app

COPY package.json /app/

RUN apk update --no-cache
RUN npm install --only=production

COPY . /app/

EXPOSE 3000

CMD [ "node", "index.js" ]
