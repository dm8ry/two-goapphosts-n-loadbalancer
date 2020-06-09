# start from the latest golang base image
FROM golang:latest

# add maintaner info
LABEL maintainer="Dmitry <dmitry.romanoff@outlook.com>"

# set the current working directory inside the container
WORKDIR /app

# copy go mod and sum files
COPY go.mod go.sum ./

# download all dependences
# dependences will be cached if no changes done on the files go.mod and go.sum
RUN go mod download

# copy the source from the current directory to the working directory inside the container
COPY . .

# build go app
RUN go build -o main .

# expose port 8080 to outside world
EXPOSE 8080

# command to run executable
CMD ["./main"]

