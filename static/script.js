document.addEventListener('DOMContentLoaded', () => {
    // Typing effect for the blinker text
    const blinker = document.getElementById('blinker');
    const messages = [
        'Exploring the digital Tao...',
        'Consciousness in code...',
        'Building tools for collective growth...',
        'Experimenting with crypto...',
        'Pondering digital philosophy...'
    ];
    let messageIndex = 0;
    let charIndex = 0;

    function typeWriter() {
        if (charIndex < messages[messageIndex].length) {
            blinker.textContent += messages[messageIndex].charAt(charIndex);
            charIndex++;
            setTimeout(typeWriter, 100);
        } else {
            setTimeout(eraseText, 2000);
        }
    }

    function eraseText() {
        if (charIndex > 0) {
            blinker.textContent = messages[messageIndex].substring(0, charIndex - 1);
            charIndex--;
            setTimeout(eraseText, 50);
        } else {
            messageIndex = (messageIndex + 1) % messages.length;
            setTimeout(typeWriter, 500);
        }
    }

    typeWriter();

    // Random quote generator
    const quotes = [
        "The Tao that can be told is not the eternal Tao.",
        "Simplicity, patience, compassion. These three are your greatest treasures.",
        "When you are content to be simply yourself and don't compare or compete, everybody will respect you.",
        "The journey of a thousand miles begins with a single step.",
        "Knowing others is intelligence; knowing yourself is true wisdom."
    ];

    const quoteElement = document.getElementById('quote');
    
    function changeQuote() {
        const randomIndex = Math.floor(Math.random() * quotes.length);
        quoteElement.textContent = quotes[randomIndex];
    }

    changeQuote();
    setInterval(changeQuote, 10000); // Change quote every 10 seconds
});
