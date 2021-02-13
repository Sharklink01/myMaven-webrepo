FROM tomcat:jdk8
ADD ./target/myMaven-web.war /usr/local/tomcat/webapps/
RUN cp -r webapps.dist/* webapps/
EXPOSE 8080
