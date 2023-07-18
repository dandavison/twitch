from setuptools import find_packages, setup

setup(
    name="twitch",
    author="Dan Davison",
    author_email="dandavison7@gmail.com",
    description="A terminal switcher",
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    install_requires=["pyyaml"],
    entry_points={
        "console_scripts": ["twitch = twitch.twitch:main"],
    },
)
