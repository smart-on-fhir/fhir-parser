import logging


def setup_logging():
    # desired log level
    log_level = logging.DEBUG

    logging.root.setLevel(log_level)
    try:
        from colorlog import ColoredFormatter

        logfmt = "  %(log_color)s%(levelname)-8s%(reset)s | %(log_color)s%(message)s%(reset)s"
        formatter = ColoredFormatter(logfmt)

        stream = logging.StreamHandler()
        stream.setLevel(log_level)
        stream.setFormatter(formatter)

        logger = logging.getLogger("fhirparser")
        logger.setLevel(log_level)
        logger.addHandler(stream)
    except Exception as e:
        logging.info('Install "colorlog" to enable colored log messages')


logger = logging.getLogger("fhirparser")
