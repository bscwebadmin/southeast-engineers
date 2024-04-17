	(function () {
		// INITIALIZATION OF MEGA MENU
		// =======================================================
		new HSMegaMenu('.js-mega-menu', {
			desktop: {
				position: 'left'
			}
		})


		// INITIALIZATION OF SHOW ANIMATIONS
		// =======================================================
		new HSShowAnimation('.js-animation-link')


		// INITIALIZATION OF BOOTSTRAP VALIDATION
		// =======================================================
		HSBsValidation.init('.js-validate', {
			onSubmit: data => {
				data.event.preventDefault()
				alert('Submited')
			}
		})


		// INITIALIZATION OF BOOTSTRAP DROPDOWN
		// =======================================================
		HSBsDropdown.init()


		// INITIALIZATION OF GO TO
		// =======================================================
		new HSGoTo('.js-go-to')
		var swiper = new Swiper(".res-slider", {
	loop: true,
	pagination: {
	  el: ".swiper-pagination",

	},
	navigation: {
	nextEl: ".swiper-button-next",
	prevEl: ".swiper-button-prev",
  },
  });

		// INITIALIZATION OF SWIPER
		// =======================================================
		var sliderThumbs = new Swiper('.js-swiper-shop-hero-thumbs', {
			watchSlidesVisibility: true,
			watchSlidesProgress: true,
			history: false,
			slidesPerView: 3,
			effect: "fade",
			spaceBetween: 15,
			autoplay: {
				delay: 3500,
				disableOnInteraction: false,
			  },
			on: {
				beforeInit: (swiper) => {
					const css = `.swiper-slide-thumb-active .swiper-thumb-progress .swiper-thumb-progress-path {
				opacity: 1;
				-webkit-animation: ${swiper.originalParams.autoplay.delay}ms linear 0ms forwards swiperThumbProgressDash;
				animation: ${swiper.originalParams.autoplay.delay}ms linear 0ms forwards swiperThumbProgressDash;
			}`
					style = document.createElement('style')
					document.head.appendChild(style)
					style.type = 'text/css'
					style.appendChild(document.createTextNode(css));

					swiper.el.querySelectorAll('.js-swiper-thumb-progress')
						.forEach(slide => {
							slide.insertAdjacentHTML('beforeend', '<span class="swiper-thumb-progress"><svg version="1.1" viewBox="0 0 160 160"><path class="swiper-thumb-progress-path" d="M 79.98452083651917 4.000001576345426 A 76 76 0 1 1 79.89443752470656 4.0000733121155605 Z"></path></svg></span>')
						})
				},
			},
		});

		var swiper = new Swiper('.js-swiper-shop-classic-hero', {
			autoplay: true,
			loop: true,
			navigation: {
				nextEl: '.js-swiper-shop-classic-hero-button-next',
				prevEl: '.js-swiper-shop-classic-hero-button-prev',
			},
			thumbs: {
				swiper: sliderThumbs
			}
		});


		// INITIALIZATION OF COUNTDOWN
		// =======================================================
		const oneYearFromNow = new Date()

		document.querySelectorAll('.js-countdown').forEach(item => {
			const days = item.querySelector('.js-cd-days'),
				hours = item.querySelector('.js-cd-hours'),
				minutes = item.querySelector('.js-cd-minutes'),
				seconds = item.querySelector('.js-cd-seconds')

			countdown(oneYearFromNow.setFullYear(
				oneYearFromNow.getFullYear() + 1),
				ts => {
					days.innerHTML = ts.days
					hours.innerHTML = ts.hours
					minutes.innerHTML = ts.minutes
					seconds.innerHTML = ts.seconds
				},
				countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS
			)
		})



		// INITIALIZATION OF SHUFFLE
		// =======================================================
		class ShufflePorfolio {
		  constructor(element) {
			this.element = element;
			this.shuffle = new Shuffle(element, {
			  itemSelector: '.js-shuffle-item',
			  speed: 500
			});

			this.addFilterButtons();
			this.addDropdownFilter(); // Call to new method for dropdown
		  }

		  addFilterButtons() {
			// Existing method for buttons...
		  }

		  // New method for handling dropdown changes
		  addDropdownFilter() {
			const dropdown = document.getElementById('js-filter-dropdown');
			if (!dropdown) {
			  return;
			}

			dropdown.addEventListener('change', (event) => {
			  const filterGroup = event.target.value;
			  this.shuffle.filter(filterGroup === 'all' ? Shuffle.ALL_ITEMS : filterGroup);
			});
		  }

		  _handleFilterClick(evt) {
			// Existing method for click handling...
		  }

		  _removeActiveClassFromChildren(parent) {
			// Existing method...
		  }
		}

		new ShufflePorfolio(document.querySelector('.js-shuffle'));
		HSCore.components.HSTomSelect.init('.js-select');


	})()

