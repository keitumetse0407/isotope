/**
 * ISOTOPE v2.0 — Main Entry Point
 *
 * Autonomous Gold Signal Intelligence System
 *
 * @author Elkai | ELEV8 DIGITAL
 * @version 2.0.0
 */

import { config, validateConfig } from './src/config.js';
import { Orchestrator } from './core/orchestrator.js';

// ============================================
// GLOBAL STATE
// ============================================

let orchestrator: Orchestrator | null = null;
let isShuttingDown = false;

// ============================================
// GRACEFUL SHUTDOWN HANDLER
// ============================================

async function shutdown(signal: string): Promise<void> {
  if (isShuttingDown) {
    console.log(`[Shutdown] Already shutting down, ignoring ${signal}`);
    return;
  }

  isShuttingDown = true;
  console.log(`\n[Shutdown] Received ${signal}, shutting down gracefully...`);

  try {
    if (orchestrator) {
      await orchestrator.stop();
    }
    console.log('[Shutdown] Cleanup complete');
    process.exit(0);
  } catch (error) {
    console.error('[Shutdown] Error during cleanup:', error);
    process.exit(1);
  }
}

// Register shutdown handlers
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('[Fatal] Uncaught exception:', error);
  shutdown('uncaughtException').catch(console.error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[Fatal] Unhandled rejection at:', promise, 'reason:', reason);
  shutdown('unhandledRejection').catch(console.error);
});

// ============================================
// INITIALIZATION
// ============================================

async function bootstrap(): Promise<void> {
  console.log('🚀 ISOTOPE v2.0 — Initializing...');
  console.log('');

  try {
    // Validate configuration
    validateConfig();
    console.log('✅ Configuration validated');

    // Create and start orchestrator
    orchestrator = new Orchestrator({
      autoSendSignals: config.app.nodeEnv === 'production',
    });

    await orchestrator.start();

    console.log('');
    console.log('✅ ISOTOPE v2.0 is running');
    console.log('');
    console.log('📊 Dashboard: http://localhost:' + config.app.dashboardPort);
    console.log('🔌 API:        http://localhost:' + config.app.port);
    console.log('');
    console.log('Press Ctrl+C to stop');
    console.log('');
  } catch (error) {
    console.error('[Startup] Failed to initialize:', error);
    await shutdown('startup_error');
  }
}

// ============================================
// START
// ============================================

bootstrap().catch(console.error);
