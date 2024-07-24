
const blinkerTexts = [
    ">> Enlightenment status: Loading...",
    ">> Seeking balance in the digital realm...",
    ">> Compiling ancient wisdom for modern times...",
    ">> Syncing consciousness with the cloud...",
    ">> Defragmenting the soul...",
    ">> Updating spiritual firmware...",
    ">> Quantum entangling with the universe...",
    ">> Decrypting the mysteries of existence...",
    ">> Optimizing karma allocation...",
    ">> Rebooting perception of reality..."
];

const quotes = [
    "\"The Tao that can be coded is not the eternal Tao. The variable that can be named is not the constant variable.\" - Waozi",
    "\"The code of the sage is bugless, yet it compiles in all machines.\" - Waozi",
    "\"In the digital age, true power lies not in controlling information, but in understanding it.\" - Waozi",
    "\"The wise programmer writes code that appears to have written itself.\" - Waozi",
    "\"As the blockchain is immutable, so too should our commitment to wisdom be unchanging.\" - Waozi",
    "\"The user interface of life is complex, but its source code is simple.\" - Waozi",
    "\"In the vastness of the internet, find your own localhost.\" - Waozi",
    "\"The firewall of the mind must be permeable to wisdom, yet impenetrable to delusion.\" - Waozi",
    "\"To master the digital realm, one must first master the self.\" - Waozi",
    "\"The most elegant solution is often the one with the fewest lines of code and the most lines of thought.\" - Waozi",
    "\"As we debug our programs, so too must we debug our minds.\" - Waozi",
    "\"The sage developer commits often to the repository of knowledge.\" - Waozi"
];

function getRandomItem(array) {
    return array[Math.floor(Math.random() * array.length)];
}

document.getElementById('blinker').textContent = getRandomItem(blinkerTexts);
document.getElementById('quote').textContent = getRandomItem(quotes);

// Smooth scrolling for navigation links
document.querySelectorAll('nav a').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

