import logging, datetime, sys, json, traceback
from logging.handlers import TimedRotatingFileHandler
import os
class ErrorFilter(object):
    def __init__(self):
        self.__level = logging.ERROR

    def filter(self, logRecord):
        return logRecord.levelno == self.__level

def log_uncaught_exceptions(ex_type, value, tb):
    logger = logging.getLogger("")
    logger.error(
        f"Uncaught exception: type {str(ex_type)}, value {str(value)}")
    logger.error(''.join(traceback.format_exception(ex_type, value, tb)))
    sys.__excepthook__(ex_type, value, tb)


def configure(config):
    logger = logging.getLogger('')
    log_root = config["logging"]["log_dir"]
    create_log_dir(log_root)

    config_root_logger()
    config_root_file_logger(logger, log_root)
    config_error_logger(logger, log_root)

def create_log_dir(log_root):
    if not os.path.exists(log_root):
        os.makedirs(log_root)

def config_root_logger():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    sys.excepthook = log_uncaught_exceptions


def config_root_file_logger(logger, log_root):
    fh = TimedRotatingFileHandler(
        log_root + '/graph_server.log',
        utc=True,
        when="D",
        atTime=datetime.time(11, 00))
    fh.suffix = "%Y%m%d"
    fh.setLevel(logging.DEBUG)
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    logger.addHandler(fh)


def config_error_logger(logger, log_root):
    eh = TimedRotatingFileHandler(
        log_root + '/error.log',
        utc=True,
        when="D",
        atTime=datetime.time(11, 00))
    eh.suffix = "%Y%m%d"
    eh.setLevel(logging.ERROR)
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    eh.setFormatter(formatter)
    eh.addFilter(ErrorFilter())
    logger.addHandler(eh)

