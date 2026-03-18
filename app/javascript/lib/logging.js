/**
 * Logger - A simple, configurable logging system for JavaScript
 *
 * Usage:
 * 1. Import the module
 *    import { Logger, configureLoggers } from './logger.js';
 *
 * 2. Create a logger
 *    const logger = new Logger('MyComponent');
 *
 * 3. Use the logger
 *    logger.debug('This is a debug message');
 *    logger.info('User logged in', { userId: 123 });
 *    logger.warn('Something might be wrong');
 *    logger.error('Failed to load data', someError);
 *
 * 4. Configure loggers globally
 *    configureLoggers('MyComponent->debug,AnotherComponent,-DisabledComponent,_all');
 *
 * Note: All instantiated loggers automatically update when configuration changes.
 */

// Log levels following standard conventions
const LOG_LEVELS = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
  off: 4
};

// Default configuration
let globalConfig = {
  defaultLevel: LOG_LEVELS.info,
  loggers: {}
};

// Registry of all instantiated loggers to update them when config changes
const loggerRegistry = new Set();

/**
 * Parse logger configuration string
 * Format: "Name->level,AnotherName,-DisabledName,_all"
 */
function parseConfig(configString) {
  if (!configString) return {};

  const config = {
    include: {},
    exclude: {}
  };

  configString.split(',').forEach(item => {
    let tag = item.trim();
    let level = null;

    if (tag.includes('->')) {
      const parts = tag.split('->');
      tag = parts[0].trim();
      level = parts[1].trim().toLowerCase();

      if (!LOG_LEVELS.hasOwnProperty(level)) {
        console.warn(`Invalid log level: ${level}`);
        level = null;
      }
    }

    if (tag.startsWith('-')) {
      tag = tag.substring(1);
      config.exclude[tag] = level !== null ? LOG_LEVELS[level] : LOG_LEVELS.off;
    } else {
      config.include[tag] = level !== null ? LOG_LEVELS[level] : null;
    }
  });

  return config;
}

/**
 * Configure all loggers
 */
export function configureLoggers(configString, defaultLevel = 'info') {
  globalConfig.loggers = parseConfig(configString);
  globalConfig.defaultLevel = LOG_LEVELS[defaultLevel.toLowerCase()]
  if (globalConfig.defaultLevel === undefined) {
    console.warn(`Invalid default log level: ${defaultLevel}`);
    globalConfig.defaultLevel = LOG_LEVELS.info;
  }

  // Update all existing loggers with new configuration
  updateAllLoggers();
}

/**
 * Update all instantiated loggers when configuration changes
 */
function updateAllLoggers() {
  loggerRegistry.forEach(logger => {
    logger.updateConfig();
  });
}

/**
 * Determine if a logger should be enabled based on its name
 */
function isLoggerEnabled(name) {
  const dbg = false;
  dbg && console.log("checking if logger is enabled for name: ", name);
  const { include, exclude } = globalConfig.loggers;

  // Excluded loggers take precedence
  if (exclude && exclude.hasOwnProperty(name)) {
    dbg && console.log("logger is excluded");
    return false;
  }

  // Check if specifically included
  if (include && include.hasOwnProperty(name)) {
    dbg && console.log("logger is included");
    return true;
  }

  // Check if all loggers are enabled by default
  if (include && include.hasOwnProperty('_all')) {
    dbg && console.log("all loggers are enabled by default", include._all);
    return include._all !== false;
  }

  dbg && console.log("logger is disabled by default");
  // Default: disabled
  return false;
}

/**
 * Get the configured level for a logger
 */
function getLoggerLevel(name) {
  const { include, exclude } = globalConfig.loggers;

  // Check specific level in include list
  if (include && include.hasOwnProperty(name) && include[name] !== null) {
    return include[name];
  }

  // Check specific level in exclude list (even though the logger is disabled)
  if (exclude && exclude.hasOwnProperty(name) && exclude[name] !== null) {
    return exclude[name];
  }

  // Default to global default level
  return globalConfig.defaultLevel;
}

/**
 * Format objects for logging
 */
function formatObject(obj) {
  try {
    if (typeof obj === 'string') return obj;
    return JSON.stringify(obj, null, 2);
  } catch (e) {
    return obj.toString();
  }
}

/**
 * Main Logger class
 */
export class Logger {
  constructor(name) {
    this.name = name;
    this.updateConfig();

    // Bind methods
    this.debug = this.debug.bind(this);
    this.info = this.info.bind(this);
    this.warn = this.warn.bind(this);
    this.error = this.error.bind(this);

    // Register this logger to receive configuration updates
    loggerRegistry.add(this);
  }

  /**
   * Update the logger's configuration based on global settings
   */
  updateConfig() {
    this.enabled = isLoggerEnabled(this.name);
    this.level = getLoggerLevel(this.name);
  }

  /**
   * Clean up and remove from registry
   */
  destroy() {
    loggerRegistry.delete(this);
  }

  /**
   * Log a message if the logger is enabled and level is appropriate
   */

  _log(level, method, message, ...args) {
    if (!this.enabled || level < this.level) return;
    const prefix = `[${this.name}][${Object.keys(LOG_LEVELS)[level].toUpperCase()}]`;
    console[method](prefix, message, ...args);
  }

  debug(message, ...args) {
    this._log(LOG_LEVELS.debug, 'debug', message, ...args);
  }

  info(message, ...args) {
    this._log(LOG_LEVELS.info, 'info', message, ...args);
  }

  warn(message, ...args) {
    this._log(LOG_LEVELS.warn, 'warn', message, ...args);
  }

  error(message, ...args) {
    this._log(LOG_LEVELS.error, 'error', message, ...args);
  }
}
