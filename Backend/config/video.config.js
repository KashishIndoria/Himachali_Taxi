const ffmpeg = require('fluent-ffmpeg');
const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

module.exports = {
    VIDEO_UPLOAD_PATH: 'uploads/videos',
    ALLOWED_VIDEO_TYPES: ['video/mp4', 'video/webm', 'video/quicktime'],
    MAX_VIDEO_SIZE: 104857600, // 100MB
    VIDEO_QUALITY_PRESETS: {
        high: {
            videoBitrate: '2000k',
            audioBitrate: '128k',
            width: 1280,
            height: 720
        },
        medium: {
            videoBitrate: '1000k',
            audioBitrate: '96k',
            width: 854,
            height: 480
        },
        low: {
            videoBitrate: '500k',
            audioBitrate: '64k',
            width: 640,
            height: 360
        }
    },
    WEBRTC_CONFIG: {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' }
        ]
    },
    VIDEO_CALL_TIMEOUT: 30000, // 30 seconds
    MAX_CALL_DURATION: 3600000, // 1 hour
    TRAINING_VIDEO_CATEGORIES: [
        'safety',
        'customer-service',
        'navigation',
        'vehicle-maintenance',
        'local-regulations',
        'emergency-procedures'
    ]
}; 