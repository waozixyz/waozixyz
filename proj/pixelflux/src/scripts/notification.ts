const showNotification = (message: string) => {
  const notificationModal = document.getElementById('notification-modal');
  const notificationMessage = document.getElementById('notification-message');
  if (notificationModal && notificationMessage) {
    notificationMessage.textContent = message;
    notificationModal.style.display = 'block';
  }
}

const hideNotification = () => {
  const notificationModal = document.getElementById('notification-modal');
  if (notificationModal) {
    notificationModal.style.display = 'none';
  }
}


export { showNotification, hideNotification }