import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'dz.filinodz.sakina',
  appName: 'صلاح الدين',
  webDir: 'dist',
  backgroundColor: '#04110d',
  android: {
    // The display must play the adhan without anyone touching the TV.
    allowMixedContent: false,
    webContentsDebuggingEnabled: false,
  },
};

export default config;
