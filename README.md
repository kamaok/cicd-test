### Description:
Простой CI/CD Jenkins-pipeline на основе nodejs-приложения, docker, динамически создаваемого EC2-инстанса для деплоя приложения.

Скачивание, unit-тестирование  и сборка docker-образа может выполняться как на мастере, так и на slave-агенте Jenkins(в зависимости от метки в поле agent)
Образ загружается на Docker Hub в публичный репозитарий
Разворачивание приложения путем  запуска контейнера из образа, созданного на этапе CI, выполняется на динамически создаваемом slave-агенте, на основе EC2-инстанса

#### Requirement:
На Jenkins master(или slave, если сборка выполняется на slave-сервере) должен быть установлен Docker(Настройка slave-агента на основе standalone linux-сервера рассмотрена в отдельной [статье](https://kamaok.org.ua/?p=2929)
Пользователь jenkins должен бать включен в группу docker(чтобы иметь возможность/привилегии выполнять команды docker)


##### На Jenkins-мастер также необходимо:
  - Создать credentials (тип Username with Password) в Jenkins для авторизации на Docker hub ( в данном случае с именем docker-hub-authentification)
  - Создать credentials (тип AWS Credentials) в Jenkins для хранение access/secret-ключей ( в данном случае с именем aws-jenkins-user)

##### Jenkins плагины:
- GitHub plugin
- Git  plugin
- Pipeline
- NodeJS ( для работы с nodejs-приложением)
- Amazon EC2 (для деплоя приложения на Jenkins-slave сервер, созданный на EC2-инстансе)
- Email Extension Plugin (для отправки уведомлений на почту)

##### Настройка Nodejs в Jenkins
```bash
Configuration->Global Tool Configuration->Nodejs->Add NodeJS
Name->node
Install automatically->Tick checkbox
Install from nodejs.org->Version NodeJS 10.0.0
```
##### Конфигурирование Email-настроек в Jenkins для отравки post-build почтовых уведомлений
```bash
Configuration->Global Tool Configuration->Extended Email notification
SMTP serever->your_email_server
Use SMTP Authentication->Tick checkbox
User Name->your_email_login
Password->your_email_password
Use SSL-> Tick checkbox(если ваш Email-сервер поддерживает SSL-подключения)
SMTP Port-> 465(если используется SSL, 25 - если не используется SSL)
```
Также желательно установить Email-адрес от которого будут отправляться письма c Jenkins-сервера
```bash
Configuration->Global Tool Configuration->Jenkins Location->Email administrator-> jenkins@jenkins<your_domain> 
```

##### В Amazon необходимо:
- В IAM создать пользователя jenkins  с генерацией Access/Secret ключей
- В IAM назначить пользователю jenkins существующую политику AmazonEC2FullAccess
- В EC2 сгенерировать SSH ключ для этого региона, в котором разворачиваться EC2-инстанс


После установки плагина Jenkins с именем Amazon EC2 plugin в настройках Jenkins появляется возможность добавить новый Cloud c Amazon EC2
```bash
Configuration-> Configuration system->Cloud->Add new cloud->Amazon EC2
```

Детальная настройка такого Cloud расписана в отдельной [статье](https://kamaok.org.ua/?p=3022)
Адоптируя ее к текущей задачи я изменил следующее:
```bash
Region –выберите регион, в котором создавали SSH-ключ
AMI ID - Базовый образ, из которого разворачиваем контейнер, Amazon Linux 2
 ami-00068cd7555f543d5  
Security group – группа, в в которой разрешены подключения по SSH и к порту, на котором слушает входящие запросы приложение(в данном случае 3000 порт)
Remote FS root-> /home/ec2-user (т.к. пользователь в этом AMI-образе имеет имя ec2-user)
Remote user -> ec2-user
Время в минутах, после которого, инстанс будет автоматически остановлен и удален.
При указании значения 0 инстанс никогда не будет остановлен/удален
Idle termination time-> 60
Subnet IDs for VPC ->одна из существующих подсетей в вашем VPC в регионе, где создавался SSH-ключ
Скрипт/команды, которые будут выполнены автоматически при первом подключении slave-агента к мастеру Jenkins(они выполняются только один раз)
```
```bash
#!/bin/bash
 yum update -y && yum install git -y
 amazon-linux-extras install docker -y
 service docker start
 usermod -a -G docker ec2-user
```

Порядок установки связи между Jenkins-мастером и EC2-slave-агентом следующий
Сначала создается  EC2-инстанс,в котором выполняется init-скрипт
После чего проверяется наличие установленной java, если она не установлено, тогда устанавливается. Затем с мастера копируется jar-файл на slave-агент и запускается на нем
После успешного запуска jar-файла мастер сообщает о том, что slave-агент запущен и сконфигурирован.После этого  на slave-агенте начинаются выполняться шаги  указанные в pipeline

В логах сборки содержится URL, на котором доступно приложение


#####Source:

 - [Nodejs application](https://github.com/prmichaelsen/cicd-test/blob/master/README.md)

 - [AWS EC2](https://kamaok.org.ua/?p=3022)

 - Email notification
     - [link1](https://medium.com/@gustavo.guss/jenkins-sending-email-on-post-build-938b236545d2)
     - [link2](https://jenkins.io/doc/pipeline/steps/email-ext/)
