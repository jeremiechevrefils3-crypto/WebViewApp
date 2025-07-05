// WebView App JavaScript
// This file handles the JavaScript-to-Swift bridge for notifications and file handling

// Main notification function that communicates with Swift
function push(title, message, delay = 0) {
    // Validate parameters
    if (!title || typeof title !== 'string') {
        console.error('Push notification requires a valid title');
        return;
    }
    
    if (!message || typeof message !== 'string') {
        console.error('Push notification requires a valid message');
        return;
    }
    
    // Convert delay to number if it's a string
    if (typeof delay === 'string') {
        delay = parseFloat(delay) || 0;
    }
    
    // Ensure delay is a non-negative number
    delay = Math.max(0, delay || 0);
    
    try {
        // Send message to Swift via WebKit message handler
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.pushNotification) {
            window.webkit.messageHandlers.pushNotification.postMessage({
                title: title,
                message: message,
                delay: delay
            });
            
            console.log(`Notification scheduled: "${title}" - "${message}" (delay: ${delay}s)`);
        } else {
            console.warn('WebKit message handler not available. Running in browser mode.');
            // Fallback for testing in browser
            if (delay > 0) {
                setTimeout(() => {
                    alert(`[${title}] ${message}`);
                }, delay * 1000);
            } else {
                alert(`[${title}] ${message}`);
            }
        }
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
}

// Test function for instant notification
function testNotification() {
    push("WebView App", "This is a test notification!", 0);
}

// Function to schedule notification with form data
function scheduleNotification() {
    const title = document.getElementById('notif-title').value.trim();
    const message = document.getElementById('notif-message').value.trim();
    const delay = parseFloat(document.getElementById('notif-delay').value) || 0;
    
    if (!title) {
        alert('Please enter a notification title');
        return;
    }
    
    if (!message) {
        alert('Please enter a notification message');
        return;
    }
    
    push(title, message, delay);
    
    // Show feedback
    const button = event.target;
    const originalText = button.textContent;
    button.textContent = delay > 0 ? `⏰ Scheduled for ${delay}s` : '✅ Sent!';
    button.style.background = 'rgba(76, 175, 80, 0.3)';
    
    setTimeout(() => {
        button.textContent = originalText;
        button.style.background = '';
    }, 2000);
}

// File handling functions
function handleFileSelect(event) {
    const files = event.target.files;
    const preview = document.getElementById('preview');
    const previewContent = document.getElementById('preview-content');
    
    if (files.length > 0) {
        preview.style.display = 'block';
        previewContent.innerHTML = '';
        
        Array.from(files).forEach((file, index) => {
            const fileInfo = document.createElement('div');
            fileInfo.style.marginBottom = '10px';
            
            const fileName = document.createElement('p');
            fileName.textContent = `File ${index + 1}: ${file.name} (${formatFileSize(file.size)})`;
            fileName.style.marginBottom = '5px';
            fileInfo.appendChild(fileName);
            
            // Create preview for images and videos
            if (file.type.startsWith('image/')) {
                const img = document.createElement('img');
                img.src = URL.createObjectURL(file);
                img.onload = () => URL.revokeObjectURL(img.src);
                fileInfo.appendChild(img);
            } else if (file.type.startsWith('video/')) {
                const video = document.createElement('video');
                video.src = URL.createObjectURL(file);
                video.controls = true;
                video.onload = () => URL.revokeObjectURL(video.src);
                fileInfo.appendChild(video);
            }
            
            previewContent.appendChild(fileInfo);
        });
        
        // Send notification about file selection
        const fileCount = files.length;
        const fileTypes = Array.from(files).map(f => f.type.split('/')[0]).join(', ');
        push("File Selected", `Selected ${fileCount} file(s): ${fileTypes}`, 0);
    }
}

// Utility function to format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Initialize event listeners when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Add event listeners for file inputs
    const cameraInput = document.getElementById('camera-input');
    const galleryInput = document.getElementById('gallery-input');
    
    if (cameraInput) {
        cameraInput.addEventListener('change', handleFileSelect);
    }
    
    if (galleryInput) {
        galleryInput.addEventListener('change', handleFileSelect);
    }
    
    // Prevent default drag and drop behavior
    document.addEventListener('dragover', function(e) {
        e.preventDefault();
    });
    
    document.addEventListener('drop', function(e) {
        e.preventDefault();
    });
    
    // Add touch feedback for buttons
    const buttons = document.querySelectorAll('.button');
    buttons.forEach(button => {
        button.addEventListener('touchstart', function() {
            this.style.transform = 'translateY(0px)';
            this.style.background = 'rgba(255, 255, 255, 0.3)';
        });
        
        button.addEventListener('touchend', function() {
            setTimeout(() => {
                this.style.transform = '';
                this.style.background = '';
            }, 150);
        });
    });
    
    console.log('WebView App JavaScript initialized');
    
    // Send welcome notification
    setTimeout(() => {
        push("Welcome", "WebView App is ready to use!", 1);
    }, 1000);
});

// Global error handler
window.addEventListener('error', function(e) {
    console.error('JavaScript error:', e.error);
    push("Error", "An error occurred in the app", 0);
});

// Export push function to global scope for easy access
window.push = push;

